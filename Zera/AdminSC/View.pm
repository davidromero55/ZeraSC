package Zera::AdminSC::View;

use JSON;
use base 'Zera::BaseAdmin::View';

sub display_brands {
    my $self = shift;

    $self->set_title('Brands');
    $self->add_search_box();
    $self->set_add_btn('/AdminSC/BrandsEdit/New', 'Add');

    # Helper buttons
    $self->add_btn('/AdminSC','Back');

    my $where;
    my @params;
    if($self->param('zl_q')){
        $where .= " name LIKE ? ";
        push(@params,'%' . $self->param('zl_q') .'%');
    }
    my $list = Zera::List->new($self->{Zera},{
        sql => {
            select => "brand_id, name, active",
            from =>"sc_brands e",
            order_by => "2",
            where => $where,
            params => \@params,
            limit => "30",
        },
        link => {
            key => "brand_id",
            hidde_key_col => 1,
            location => '/AdminSC/BrandsEdit',
            transit_params => {},
        },
        debug => 1,
    });

    $list->get_data();
    $list->on_off('active');
    $list->columns_align(['left','left','center']);

    my $vars = {
        list => $list->print(),
    };

    return $self->render_template($vars);
}

sub display_brands_edit {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");

    $self->param('brand_id',$self->param('SubView')) if(!($self->param('brand_id')));

    # Title
    ($self->param('SubView') eq 'New') ? $self->set_title('Add Brand') : $self->set_title('Edit Brand');

    # Helper buttons
    $self->add_btn('/AdminSC/Brands','Back');

    # Values
    if($self->param('brand_id') ne 'New'){
        $values = $self->selectrow_hashref("SELECT *, image as photo  FROM sc_brands WHERE brand_id=?",{},$self->param('brand_id'));
        push(@submit, 'Delete');

    }else{
        $values = {
            date => $self->selectrow_array('SELECT DATE(NOW())'),
            active => 1,
            photo=>'arreglalo02.jpg',
        };
    }

    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/brand_id name description image active /],
        submits  => \@submit,
        values   => $values,
    });

    $form->field('brand_id',{type=>'hidden'});
    $form->field('name',{span=>'col-md-9', required=>1});
    $form->field('description',{span=>'col-md-9', required=>1});
    $form->field('image', {type=>'file', accept=>"image/x-png,image/gif,image/jpeg", span=>'col-6'});
    $form->field('active',{label=>"Active", span=>'col-md-1', check_label=>'Yes / No', class=>"filled-in", type=>"checkbox"});

    $form->submit('Delete',{class=>'btn btn-danger'});
    if($values->{photo}){
        $form->field('photo',{label=>"Logo", span=>'col-md-12', type=>"image"});
        push(@submit, 'Delete Logo');
        $form->submit('Delete Logo',{class=>'btn btn-danger'});
        #$form->field('image', {help=>$self->get_image_options($values->{display_options}->{image})});
    }


    return $form->render();
}

1;
